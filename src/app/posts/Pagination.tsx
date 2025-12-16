"use client";
import React from "react";

interface PaginationProps {
  currentPage: number;
  totalPages: number;
  onPageChange: (page: number) => void;
}

export function Pagination({ currentPage, totalPages, onPageChange }: PaginationProps) {
  if (totalPages <= 1) return null;

  // Show up to 5 page buttons, with ellipsis if needed
  const pageNumbers: (number | string)[] = [];
  const maxButtons = 5;
  let start = Math.max(1, currentPage - 2);
  let end = Math.min(totalPages, start + maxButtons - 1);
  if (end - start < maxButtons - 1) {
    start = Math.max(1, end - maxButtons + 1);
  }

  if (start > 1) pageNumbers.push(1);
  if (start > 2) pageNumbers.push("...");
  for (let i = start; i <= end; i++) pageNumbers.push(i);
  if (end < totalPages - 1) pageNumbers.push("...");
  if (end < totalPages) pageNumbers.push(totalPages);

  return (
    <nav className="flex gap-1 mt-4" aria-label="Pagination">
      {pageNumbers.map((num, idx) =>
        typeof num === "number" ? (
          <button
            key={num}
            onClick={() => onPageChange(num)}
            className={`px-3 py-1 rounded border text-sm ${
              num === currentPage
                ? "bg-black text-white border-black"
                : "bg-white text-black border-gray-300 hover:bg-gray-100"
            }`}
            aria-current={num === currentPage ? "page" : undefined}
          >
            {num}
          </button>
        ) : (
          <span key={"ellipsis-" + idx} className="px-2 py-1 text-gray-400">
            ...
          </span>
        )
      )}
    </nav>
  );
}
